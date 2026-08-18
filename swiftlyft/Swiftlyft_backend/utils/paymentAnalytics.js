/**
 * MongoDB Aggregation Pipelines for Payment Analytics
 * This file contains various aggregation pipelines for payment reporting and analytics
 */

class PaymentAnalytics {
  constructor() {
    this.collection = null;
  }

  /**
   * Get payment statistics by user
   */
  getUserPaymentStats(userId) {
    return [
      {
        $match: { userId: userId }
      },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalAmount: { $sum: '$amount' },
          avgAmount: { $avg: '$amount' }
        }
      },
      {
        $group: {
          _id: null,
          stats: {
            $push: {
              status: '$_id',
              count: '$count',
              totalAmount: '$totalAmount',
              avgAmount: '$avgAmount'
            }
          },
          totalTransactions: { $sum: '$count' },
          totalSpent: { $sum: '$totalAmount' }
        }
      },
      {
        $project: {
          _id: 0,
          totalTransactions: 1,
          totalSpent: 1,
          statusBreakdown: '$stats'
        }
      }
    ];
  }

  /**
   * Get payment trends over time
   */
  getPaymentTrends(startDate, endDate, groupBy = 'day') {
    const groupFormat = groupBy === 'day' ? '%Y-%m-%d' : 
                       groupBy === 'month' ? '%Y-%m' : 
                       '%Y-%m-%d';

    return [
      {
        $match: {
          createdAt: {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
          }
        }
      },
      {
        $group: {
          _id: {
            $dateToString: {
              format: groupFormat,
              date: '$createdAt'
            }
          },
          totalAmount: { $sum: '$amount' },
          totalTransactions: { $sum: 1 },
          completedTransactions: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          failedTransactions: {
            $sum: { $cond: [{ $eq: ['$status', 'failed'] }, 1, 0] }
          },
          avgAmount: { $avg: '$amount' },
          totalProcessingFees: { $sum: '$processingFee' },
          totalNetAmount: { $sum: '$netAmount' }
        }
      },
      {
        $addFields: {
          successRate: {
            $multiply: [
              { $divide: ['$completedTransactions', '$totalTransactions'] },
              100
            ]
          }
        }
      },
      {
        $sort: { _id: 1 }
      }
    ];
  }

  /**
   * Get payment method usage statistics
   */
  getPaymentMethodStats() {
    return [
      {
        $lookup: {
          from: 'paymentmethods',
          localField: 'paymentMethodId',
          foreignField: '_id',
          as: 'paymentMethod'
        }
      },
      {
        $unwind: '$paymentMethod'
      },
      {
        $group: {
          _id: {
            type: '$paymentMethod.type',
            provider: '$paymentMethod.provider'
          },
          totalTransactions: { $sum: 1 },
          totalAmount: { $sum: '$amount' },
          avgAmount: { $avg: '$amount' },
          successRate: {
            $avg: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          }
        }
      },
      {
        $group: {
          _id: '$_id.type',
          providers: {
            $push: {
              provider: '$_id.provider',
              totalTransactions: '$totalTransactions',
              totalAmount: '$totalAmount',
              avgAmount: '$avgAmount',
              successRate: '$successRate'
            }
          },
          totalTransactions: { $sum: '$totalTransactions' },
          totalAmount: { $sum: '$totalAmount' }
        }
      },
      {
        $sort: { totalTransactions: -1 }
      }
    ];
  }

  /**
   * Get refund analytics
   */
  getRefundAnalytics(startDate, endDate) {
    return [
      {
        $match: {
          createdAt: {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
          },
          totalRefunded: { $gt: 0 }
        }
      },
      {
        $group: {
          _id: null,
          totalRefunds: { $sum: 1 },
          totalRefundAmount: { $sum: '$totalRefunded' },
          avgRefundAmount: { $avg: '$totalRefunded' },
          refundReasons: {
            $push: {
              $reduce: {
                input: '$refunds',
                initialValue: [],
                in: { $concatArrays: ['$$value', ['$$this.reason']] }
              }
            }
          }
        }
      },
      {
        $unwind: '$refundReasons'
      },
      {
        $unwind: '$refundReasons'
      },
      {
        $group: {
          _id: '$refundReasons',
          count: { $sum: 1 }
        }
      },
      {
        $group: {
          _id: null,
          refundStats: {
            totalRefunds: { $first: '$totalRefunds' },
            totalRefundAmount: { $first: '$totalRefundAmount' },
            avgRefundAmount: { $first: '$avgRefundAmount' }
          },
          refundReasons: {
            $push: {
              reason: '$_id',
              count: '$count'
            }
          }
        }
      }
    ];
  }

  /**
   * Get revenue analytics
   */
  getRevenueAnalytics(startDate, endDate) {
    return [
      {
        $match: {
          createdAt: {
            $gte: new Date(startDate),
            $lte: new Date(endDate)
          },
          status: 'completed'
        }
      },
      {
        $group: {
          _id: {
            currency: '$currency'
          },
          totalRevenue: { $sum: '$amount' },
          totalNetRevenue: { $sum: '$netAmount' },
          totalProcessingFees: { $sum: '$processingFee' },
          transactionCount: { $sum: 1 },
          avgTransactionValue: { $avg: '$amount' },
          avgNetValue: { $avg: '$netAmount' }
        }
      },
      {
        $addFields: {
          processingFeePercentage: {
            $multiply: [
              { $divide: ['$totalProcessingFees', '$totalRevenue'] },
              100
            ]
          }
        }
      },
      {
        $sort: { totalRevenue: -1 }
      }
    ];
  }

  /**
   * Get user payment behavior analytics
   */
  getUserPaymentBehavior() {
    return [
      {
        $group: {
          _id: '$userId',
          totalTransactions: { $sum: 1 },
          totalSpent: { $sum: '$amount' },
          avgTransactionValue: { $avg: '$amount' },
          successRate: {
            $avg: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          firstPayment: { $min: '$createdAt' },
          lastPayment: { $max: '$createdAt' },
          paymentMethods: { $addToSet: '$paymentMethodId' }
        }
      },
      {
        $addFields: {
          paymentMethodCount: { $size: '$paymentMethods' },
          daysSinceFirstPayment: {
            $divide: [
              { $subtract: [new Date(), '$firstPayment'] },
              1000 * 60 * 60 * 24
            ]
          },
          daysSinceLastPayment: {
            $divide: [
              { $subtract: [new Date(), '$lastPayment'] },
              1000 * 60 * 60 * 24
            ]
          }
        }
      },
      {
        $group: {
          _id: null,
          totalUsers: { $sum: 1 },
          avgTransactionsPerUser: { $avg: '$totalTransactions' },
          avgSpentPerUser: { $avg: '$totalSpent' },
          avgTransactionValue: { $avg: '$avgTransactionValue' },
          avgSuccessRate: { $avg: '$successRate' },
          avgPaymentMethodsPerUser: { $avg: '$paymentMethodCount' },
          userSegments: {
            $push: {
              userId: '$_id',
              totalTransactions: '$totalTransactions',
              totalSpent: '$totalSpent',
              avgTransactionValue: '$avgTransactionValue',
              successRate: '$successRate',
              paymentMethodCount: '$paymentMethodCount',
              daysSinceFirstPayment: '$daysSinceFirstPayment',
              daysSinceLastPayment: '$daysSinceLastPayment'
            }
          }
        }
      }
    ];
  }

  /**
   * Get failed payment analysis
   */
  getFailedPaymentAnalysis() {
    return [
      {
        $match: { status: 'failed' }
      },
      {
        $lookup: {
          from: 'paymentmethods',
          localField: 'paymentMethodId',
          foreignField: '_id',
          as: 'paymentMethod'
        }
      },
      {
        $unwind: '$paymentMethod'
      },
      {
        $group: {
          _id: {
            provider: '$paymentMethod.provider',
            failureReason: '$processorResponse.message'
          },
          count: { $sum: 1 },
          totalAmount: { $sum: '$amount' },
          avgAmount: { $avg: '$amount' }
        }
      },
      {
        $group: {
          _id: '$_id.provider',
          failureReasons: {
            $push: {
              reason: '$_id.failureReason',
              count: '$count',
              totalAmount: '$totalAmount',
              avgAmount: '$avgAmount'
            }
          },
          totalFailures: { $sum: '$count' },
          totalFailedAmount: { $sum: '$totalAmount' }
        }
      },
      {
        $sort: { totalFailures: -1 }
      }
    ];
  }

  /**
   * Get monthly payment summary
   */
  getMonthlyPaymentSummary(year, month) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    return [
      {
        $match: {
          createdAt: {
            $gte: startDate,
            $lte: endDate
          }
        }
      },
      {
        $group: {
          _id: null,
          totalTransactions: { $sum: 1 },
          totalAmount: { $sum: '$amount' },
          totalNetAmount: { $sum: '$netAmount' },
          totalProcessingFees: { $sum: '$processingFee' },
          completedTransactions: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          failedTransactions: {
            $sum: { $cond: [{ $eq: ['$status', 'failed'] }, 1, 0] }
          },
          refundedTransactions: {
            $sum: { $cond: [{ $eq: ['$status', 'refunded'] }, 1, 0] }
          },
          totalRefunded: { $sum: '$totalRefunded' },
          avgTransactionValue: { $avg: '$amount' },
          avgNetValue: { $avg: '$netAmount' }
        }
      },
      {
        $addFields: {
          successRate: {
            $multiply: [
              { $divide: ['$completedTransactions', '$totalTransactions'] },
              100
            ]
          },
          failureRate: {
            $multiply: [
              { $divide: ['$failedTransactions', '$totalTransactions'] },
              100
            ]
          },
          refundRate: {
            $multiply: [
              { $divide: ['$refundedTransactions', '$completedTransactions'] },
              100
            ]
          },
          processingFeePercentage: {
            $multiply: [
              { $divide: ['$totalProcessingFees', '$totalAmount'] },
              100
            ]
          }
        }
      }
    ];
  }
}

module.exports = PaymentAnalytics;
